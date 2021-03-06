#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;
use Test::Exception;

BEGIN {
    use_ok('Forest::Tree');
    use_ok('Forest::Tree::Loader');
    use_ok('Forest::Tree::Loader::SimpleUIDLoader');
};

my $data = [
    { node => '1.0',   uid => 1,  parent_uid => 0 },
    { node => '1.1',   uid => 2,  parent_uid => 1 },
    { node => '1.2',   uid => 3,  parent_uid => 1 },
    { node => '1.2.1', uid => 4,  parent_uid => 3 },
    { node => '2.0',   uid => 5,  parent_uid => 0 },
    { node => '2.1',   uid => 6,  parent_uid => 5 },
    { node => '3.0',   uid => 7,  parent_uid => 0 },
    { node => '4.0',   uid => 8,  parent_uid => 0 },
    { node => '4.1',   uid => 9,  parent_uid => 8 },
    { node => '4.1.1', uid => 10, parent_uid => 9 },
];

{
    package My::Tree;
    use Moose;
    
    extends 'Forest::Tree';
       with 'Forest::Tree::Roles::MetaData';
}

{
    package My::Tree::Loader::WithMetaData;
    use Moose;

    extends 'Forest::Tree::Loader::SimpleUIDLoader';
       with 'Forest::Tree::Roles::LoadWithMetaData';
       
    has '+tree' => (default => sub { My::Tree->new });
}

{
    my $loader = My::Tree::Loader::WithMetaData->new(
        metadata => {
            1 => { name => 'one'   },
            5 => { name => 'two'   },
            7 => { name => 'three' },
            8 => { name => 'four'  },
        }
    );
    isa_ok($loader, 'My::Tree::Loader::WithMetaData');
    isa_ok($loader, 'Forest::Tree::Loader::SimpleUIDLoader');
    ok($loader->does('Forest::Tree::Loader'), '... loader does Forest::Tree::Loader');
    ok($loader->does('Forest::Tree::Roles::LoadWithMetaData'), '... loader does LoadWithMetaData');

    my $tree = $loader->tree;
    isa_ok($tree, 'My::Tree');
    isa_ok($tree, 'Forest::Tree');

    ok($tree->is_root, '... tree is a root');
    ok($tree->is_leaf, '... tree is a leaf');
    is($tree->child_count, 0, '... tree has no children');

    lives_ok {
        $loader->load($data);
    } '... loaded the tree';

    ok($tree->is_root, '... tree is a root');
    ok(!$tree->is_leaf, '... tree is not a leaf');
    is($tree->child_count, 4, '... tree has 4 children');

    is($tree->get_child_at(0)->node, '1.0', '... got the right node');
    is_deeply($tree->get_child_at(0)->metadata, { name => 'one' }, '... got the right metadata');
    is($tree->get_child_at(0)->get_child_at(0)->node, '1.1', '... got the right node');
    is($tree->get_child_at(0)->get_child_at(1)->node, '1.2', '... got the right node');
    is($tree->get_child_at(0)->get_child_at(1)->get_child_at(0)->node, '1.2.1', '... got the right node');

    is($tree->get_child_at(1)->node, '2.0', '... got the right node');
    is_deeply($tree->get_child_at(1)->metadata, { name => 'two' }, '... got the right metadata');
    is($tree->get_child_at(1)->get_child_at(0)->node, '2.1', '... got the right node');

    is($tree->get_child_at(2)->node, '3.0', '... got the right node');
    is_deeply($tree->get_child_at(2)->metadata, { name => 'three' }, '... got the right metadata');    

    is($tree->get_child_at(3)->node, '4.0', '... got the right node');
    is_deeply($tree->get_child_at(3)->metadata, { name => 'four' }, '... got the right metadata');    
    is($tree->get_child_at(3)->get_child_at(0)->node, '4.1', '... got the right node');
    is($tree->get_child_at(3)->get_child_at(0)->get_child_at(0)->node, '4.1.1', '... got the right node');

}

