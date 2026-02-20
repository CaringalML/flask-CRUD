from flask import Blueprint, render_template, request, redirect, url_for, flash
from extensions import db
from models import Item

main = Blueprint('main', __name__)

@main.route('/')
def index():
    items = Item.query.all()
    return render_template('index.html', items=items)

@main.route('/create', methods=['GET', 'POST'])
def create():
    if request.method == 'POST':
        name = request.form.get('name')
        description = request.form.get('description')
        
        if not name:
            flash('Item name is required!', 'warning')
            return redirect(url_for('main.create'))
        
        item = Item(name=name, description=description)
        db.session.add(item)
        db.session.commit()
        
        flash(f'Item "{name}" created successfully!', 'success')
        return redirect(url_for('main.index'))
    
    return render_template('form.html')

@main.route('/edit/<int:item_id>', methods=['GET', 'POST'])
def edit(item_id):
    item = Item.query.get_or_404(item_id)
    
    if request.method == 'POST':
        name = request.form.get('name')
        description = request.form.get('description')
        
        if not name:
            flash('Item name is required!', 'warning')
            return redirect(url_for('main.edit', item_id=item_id))
        
        item.name = name
        item.description = description
        db.session.commit()
        
        flash(f'Item "{name}" updated successfully!', 'success')
        return redirect(url_for('main.index'))
    
    return render_template('form.html', item=item)

@main.route('/delete/<int:item_id>', methods=['POST'])
def delete(item_id):
    item = Item.query.get_or_404(item_id)
    item_name = item.name
    db.session.delete(item)
    db.session.commit()
    
    flash(f'Item "{item_name}" deleted successfully!', 'success')
    return redirect(url_for('main.index'))
