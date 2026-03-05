import os
from flask import Blueprint, render_template, request, redirect, url_for, flash, make_response
from extensions import supabase
from datetime import datetime
import json

main = Blueprint('main', __name__)


def is_htmx_request():
    return request.headers.get('HX-Request') == 'true'


def htmx_toast_response(html, message, msg_type='success', status=200):
    """Return an HTMX response with a toast trigger header."""
    resp = make_response(html, status)
    resp.headers['HX-Trigger'] = json.dumps({
        'showToast': {'message': message, 'type': msg_type}
    })
    return resp


@main.route('/')
def index():
    try:
        response = supabase.table('items').select("*").execute()
        items = response.data
    except Exception as e:
        flash(f'Error loading items: {str(e)}', 'danger')
        items = []

    return render_template(
        'index.html',
        items=items,
        supabase_url=os.getenv('SUPABASE_URL'),
        supabase_anon_key=os.getenv('SUPABASE_ANON_KEY')
    )


@main.route('/create', methods=['GET', 'POST'])
def create():
    if request.method == 'POST':
        name = request.form.get('name')
        description = request.form.get('description')

        if not name:
            flash('Item name is required!', 'warning')
            return redirect(url_for('main.create'))

        try:
            supabase.table('items').insert({
                'name': name,
                'description': description,
                'created_at': datetime.utcnow().isoformat(),
                'updated_at': datetime.utcnow().isoformat()
            }).execute()

            flash(f'Item "{name}" created successfully!', 'success')
            return redirect(url_for('main.index'))
        except Exception as e:
            flash(f'Error creating item: {str(e)}', 'danger')
            return redirect(url_for('main.create'))

    return render_template('form.html')


# --- HTMX endpoints ---

@main.route('/htmx/create', methods=['POST'])
def create_htmx():
    """HTMX: create item and return partial."""
    name = request.form.get('name', '').strip()
    description = request.form.get('description', '').strip()

    if not name:
        return render_template('partials/form_error.html', message='Item name is required!'), 422

    try:
        supabase.table('items').insert({
            'name': name,
            'description': description,
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat()
        }).execute()

        return render_template('partials/form_success.html',
                               message=f'Item "{name}" created successfully!')
    except Exception as e:
        return render_template('partials/form_error.html',
                               message=f'Error creating item: {str(e)}'), 500


@main.route('/htmx/items/<int:item_id>', methods=['PUT'])
def update_htmx(item_id):
    """HTMX: inline update item and return updated card partial."""
    name = request.form.get('name', '').strip()
    description = request.form.get('description', '').strip()

    if not name:
        return render_template('partials/form_error.html', message='Item name is required!'), 422

    try:
        supabase.table('items').update({
            'name': name,
            'description': description,
            'updated_at': datetime.utcnow().isoformat()
        }).eq('id', item_id).execute()

        # Fetch updated item
        response = supabase.table('items').select("*").eq('id', item_id).execute()
        item = response.data[0]

        html = render_template('partials/item_card.html', item=item)
        return htmx_toast_response(html, f'Item "{name}" updated!')
    except Exception as e:
        return render_template('partials/form_error.html',
                               message=f'Error updating item: {str(e)}'), 500


@main.route('/htmx/items/<int:item_id>', methods=['DELETE'])
def delete_htmx(item_id):
    """HTMX: delete item and return empty (removes card from DOM)."""
    try:
        response = supabase.table('items').select("name").eq('id', item_id).execute()
        if not response.data:
            return htmx_toast_response('', 'Item not found!', 'error', 404)

        item_name = response.data[0]['name']
        supabase.table('items').delete().eq('id', item_id).execute()

        return htmx_toast_response('', f'Item "{item_name}" deleted!', 'success')
    except Exception as e:
        return htmx_toast_response('', f'Error deleting item: {str(e)}', 'error', 500)


@main.route('/htmx/edit/<int:item_id>', methods=['POST'])
def edit_htmx(item_id):
    """HTMX: form-page edit (from the dedicated edit page)."""
    name = request.form.get('name', '').strip()
    description = request.form.get('description', '').strip()

    if not name:
        return render_template('partials/form_error.html', message='Item name is required!'), 422

    try:
        supabase.table('items').update({
            'name': name,
            'description': description,
            'updated_at': datetime.utcnow().isoformat()
        }).eq('id', item_id).execute()

        return render_template('partials/form_success.html',
                               message=f'Item "{name}" updated successfully!')
    except Exception as e:
        return render_template('partials/form_error.html',
                               message=f'Error updating item: {str(e)}'), 500


@main.route('/htmx/items/<int:item_id>/edit', methods=['GET'])
def edit_inline(item_id):
    """HTMX: return inline edit form partial for a card."""
    try:
        response = supabase.table('items').select("*").eq('id', item_id).execute()
        if not response.data:
            return '<p class="alert alert-danger">Item not found</p>', 404
        item = response.data[0]
        return render_template('partials/item_edit.html', item=item)
    except Exception as e:
        return f'<p class="alert alert-danger">Error: {str(e)}</p>', 500


@main.route('/htmx/items/<int:item_id>/card', methods=['GET'])
def card_htmx(item_id):
    """HTMX: return single item card (used by Cancel in inline edit and Realtime inserts/updates)."""
    try:
        response = supabase.table('items').select("*").eq('id', item_id).execute()
        if not response.data:
            return '', 404
        item = response.data[0]
        return render_template('partials/item_card.html', item=item)
    except Exception as e:
        return f'<p class="alert alert-danger">Error: {str(e)}</p>', 500


# Keep original edit/delete for non-HTMX fallback
@main.route('/edit/<int:item_id>', methods=['GET', 'POST'])
def edit(item_id):
    try:
        response = supabase.table('items').select("*").eq('id', item_id).execute()
        if not response.data:
            flash('Item not found!', 'danger')
            return redirect(url_for('main.index'))

        item = response.data[0]
    except Exception as e:
        flash(f'Error loading item: {str(e)}', 'danger')
        return redirect(url_for('main.index'))

    if request.method == 'POST':
        name = request.form.get('name')
        description = request.form.get('description')

        if not name:
            flash('Item name is required!', 'warning')
            return redirect(url_for('main.edit', item_id=item_id))

        try:
            supabase.table('items').update({
                'name': name,
                'description': description,
                'updated_at': datetime.utcnow().isoformat()
            }).eq('id', item_id).execute()

            flash(f'Item "{name}" updated successfully!', 'success')
            return redirect(url_for('main.index'))
        except Exception as e:
            flash(f'Error updating item: {str(e)}', 'danger')
            return redirect(url_for('main.edit', item_id=item_id))

    return render_template('form.html', item=item)


@main.route('/delete/<int:item_id>', methods=['POST'])
def delete(item_id):
    try:
        response = supabase.table('items').select("name").eq('id', item_id).execute()
        if not response.data:
            flash('Item not found!', 'danger')
            return redirect(url_for('main.index'))

        item_name = response.data[0]['name']

        supabase.table('items').delete().eq('id', item_id).execute()

        flash(f'Item "{item_name}" deleted successfully!', 'success')
    except Exception as e:
        flash(f'Error deleting item: {str(e)}', 'danger')

    return redirect(url_for('main.index'))