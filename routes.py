from flask import Blueprint, render_template, request, redirect, url_for, flash
from extensions import supabase
from datetime import datetime

main = Blueprint('main', __name__)

@main.route('/')
def index():
    try:
        response = supabase.table('items').select("*").execute()
        items = response.data
    except Exception as e:
        flash(f'Error loading items: {str(e)}', 'danger')
        items = []
    
    return render_template('index.html', items=items)

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
