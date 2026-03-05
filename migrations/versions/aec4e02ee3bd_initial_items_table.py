"""initial items table

Revision ID: aec4e02ee3bd
Revises: 
Create Date: 2026-03-05 15:30:30.921608

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'aec4e02ee3bd'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('items',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('name', sa.String(length=100), nullable=False),
    sa.Column('description', sa.Text(), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.Column('updated_at', sa.DateTime(), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    # ### end Alembic commands ###


def downgrade():
    op.drop_table('items')
    # ### end Alembic commands ###
