-- $Id: stock.sql,v 1.7 2007-03-23 15:18:03 scottcain Exp $
-- ==========================================
-- Chado stock module
--
-- DEPENDENCIES
-- ============
-- :import cvterm from cv
-- :import pub from pub
-- :import dbxref from db
-- :import organism from organism
-- :import genotype from genetic
-- :import contact from contact
-- :import feature from sequence
-- :import featuremap from map
-- ================================================
-- TABLE: stock
-- ================================================

create table stock (
       stock_id bigserial not null,
       primary key (stock_id),
       dbxref_id bigint,
       foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
       organism_id bigint,
       foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
       name varchar(255),
       uniquename text not null,
       description text,
       type_id bigint not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       is_obsolete boolean not null default 'false',
       constraint stock_c1 unique (organism_id,uniquename,type_id)
);
create index stock_name_ind1 on stock (name);
create index stock_idx1 on stock (dbxref_id);
create index stock_idx2 on stock (organism_id);
create index stock_idx3 on stock (type_id);
create index stock_idx4 on stock (uniquename);

COMMENT ON TABLE stock IS 'Any stock can be globally identified by the
combination of organism, uniquename and stock type. A stock is the physical entities, either living or preserved, held by collections. Stocks belong to a collection; they have IDs, type, organism, description and may have a genotype.';
COMMENT ON COLUMN stock.dbxref_id IS 'The dbxref_id is an optional primary stable identifier for this stock. Secondary indentifiers and external dbxrefs go in table: stock_dbxref.';
COMMENT ON COLUMN stock.organism_id IS 'The organism_id is the organism to which the stock belongs. This column should only be left blank if the organism cannot be determined.';
COMMENT ON COLUMN stock.type_id IS 'The type_id foreign key links to a controlled vocabulary of stock types. The would include living stock, genomic DNA, preserved specimen. Secondary cvterms for stocks would go in stock_cvterm.';
COMMENT ON COLUMN stock.description IS 'The description is the genetic description provided in the stock list.';
COMMENT ON COLUMN stock.name IS 'The name is a human-readable local name for a stock.';


-- ================================================
-- TABLE: stock_pub
-- ================================================

create table stock_pub (
       stock_pub_id bigserial not null,
       primary key (stock_pub_id),
       stock_id bigint not null,
       foreign key (stock_id) references stock (stock_id)  on delete cascade INITIALLY DEFERRED,
       pub_id bigint not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint stock_pub_c1 unique (stock_id,pub_id)
);
create index stock_pub_idx1 on stock_pub (stock_id);
create index stock_pub_idx2 on stock_pub (pub_id);

COMMENT ON TABLE stock_pub IS 'Provenance. Linking table between stocks and, for example, a stocklist computer file.';


-- ================================================
-- TABLE: stockprop
-- ================================================

create table stockprop (
       stockprop_id bigserial not null,
       primary key (stockprop_id),
       stock_id bigint not null,
       foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
       type_id bigint not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       value text null,
       rank int not null default 0,
       cvalue_id bigint,
       FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
       constraint stockprop_c1 unique (stock_id,type_id,rank),
);
create index stockprop_idx1 on stockprop (stock_id);
create index stockprop_idx2 on stockprop (type_id);
CREATE INDEX stockprop_idx3 ON stockprop (cvalue_id);

COMMENT ON TABLE stockprop IS 'A stock can have any number of
slot-value property tags attached to it. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, stockprop_c1, for
the combination of stock_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.';
COMMENT ON COLUMN stockprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';


-- ================================================
-- TABLE: stockprop_pub
-- ================================================

create table stockprop_pub (
     stockprop_pub_id bigserial not null,
     primary key (stockprop_pub_id),
     stockprop_id bigint not null,
     foreign key (stockprop_id) references stockprop (stockprop_id) on delete cascade INITIALLY DEFERRED,
     pub_id bigint not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint stockprop_pub_c1 unique (stockprop_id,pub_id)
);
create index stockprop_pub_idx1 on stockprop_pub (stockprop_id);
create index stockprop_pub_idx2 on stockprop_pub (pub_id); 

COMMENT ON TABLE stockprop_pub IS 'Provenance. Any stockprop assignment can optionally be supported by a publication.';


-- ================================================
-- TABLE: stock_relationship
-- ================================================

create table stock_relationship (
       stock_relationship_id bigserial not null,
       primary key (stock_relationship_id),
       subject_id bigint not null,
       foreign key (subject_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
       object_id bigint not null,
       foreign key (object_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
       type_id bigint not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       value text null,
       rank int not null default 0,
       constraint stock_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index stock_relationship_idx1 on stock_relationship (subject_id);
create index stock_relationship_idx2 on stock_relationship (object_id);
create index stock_relationship_idx3 on stock_relationship (type_id);

COMMENT ON COLUMN stock_relationship.subject_id IS 'stock_relationship.subject_id is the subject of the subj-predicate-obj sentence. This is typically the substock.';
COMMENT ON COLUMN stock_relationship.object_id IS 'stock_relationship.object_id is the object of the subj-predicate-obj sentence. This is typically the container stock.';
COMMENT ON COLUMN stock_relationship.type_id IS 'stock_relationship.type_id is relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed.';
COMMENT ON COLUMN stock_relationship.rank IS 'stock_relationship.rank is the ordering of subject stocks with respect to the object stock may be important where rank is used to order these; starts from zero.';
COMMENT ON COLUMN stock_relationship.value IS 'stock_relationship.value is for additional notes or comments.';



-- ================================================
-- TABLE: stock_relationship_cvterm
-- ================================================

CREATE TABLE stock_relationship_cvterm (
	stock_relationship_cvterm_id bigserial NOT NULL,
	PRIMARY KEY (stock_relationship_cvterm_id),
	stock_relationship_id bigint NOT NULL,
	FOREIGN KEY (stock_relationship_id) references stock_relationship (stock_relationship_id) ON DELETE CASCADE INITIALLY DEFERRED,
	cvterm_id bigint NOT NULL,
	FOREIGN KEY (cvterm_id) REFERENCES cvterm (cvterm_id) ON DELETE RESTRICT,
	pub_id bigint,
	FOREIGN KEY (pub_id) REFERENCES pub (pub_id) ON DELETE RESTRICT
);
COMMENT ON TABLE stock_relationship_cvterm is 'For germplasm maintenance and pedigree data, stock_relationship. type_id will record cvterms such as "is a female parent of", "a parent for mutation", "is a group_id of", "is a source_id of", etc The cvterms for higher categories such as "generative", "derivative" or "maintenance" can be stored in table stock_relationship_cvterm';


-- ================================================
-- TABLE: stock_relationship_pub
-- ================================================

create table stock_relationship_pub (
      stock_relationship_pub_id bigserial not null,
      primary key (stock_relationship_pub_id),
      stock_relationship_id bigint not null,
      foreign key (stock_relationship_id) references stock_relationship (stock_relationship_id) on delete cascade INITIALLY DEFERRED,
      pub_id bigint not null,
      foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
      constraint stock_relationship_pub_c1 unique (stock_relationship_id,pub_id)
);
create index stock_relationship_pub_idx1 on stock_relationship_pub (stock_relationship_id);
create index stock_relationship_pub_idx2 on stock_relationship_pub (pub_id);

COMMENT ON TABLE stock_relationship_pub IS 'Provenance. Attach optional evidence to a stock_relationship in the form of a publication.';


-- ================================================
-- TABLE: stock_dbxref
-- ================================================

create table stock_dbxref (
     stock_dbxref_id bigserial not null,
     primary key (stock_dbxref_id),
     stock_id bigint not null,
     foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
     dbxref_id bigint not null,
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
     is_current boolean not null default 'true',
     constraint stock_dbxref_c1 unique (stock_id,dbxref_id)
);
create index stock_dbxref_idx1 on stock_dbxref (stock_id);
create index stock_dbxref_idx2 on stock_dbxref (dbxref_id);

COMMENT ON TABLE stock_dbxref IS 'stock_dbxref links a stock to dbxrefs. This is for secondary identifiers; primary identifiers should use stock.dbxref_id.';
COMMENT ON COLUMN stock_dbxref.is_current IS 'The is_current boolean indicates whether the linked dbxref is the current -official- dbxref for the linked stock.';


-- ================================================
-- TABLE: stock_cvterm
-- ================================================

create table stock_cvterm (
     stock_cvterm_id bigserial not null,
     primary key (stock_cvterm_id),
     stock_id bigint not null,
     foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
     cvterm_id bigint not null,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     pub_id bigint not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     is_not boolean not null default false,
     rank int not null default 0,
     constraint stock_cvterm_c1 unique (stock_id,cvterm_id,pub_id,rank)
 );
create index stock_cvterm_idx1 on stock_cvterm (stock_id);
create index stock_cvterm_idx2 on stock_cvterm (cvterm_id);
create index stock_cvterm_idx3 on stock_cvterm (pub_id);

COMMENT ON TABLE stock_cvterm IS 'stock_cvterm links a stock to cvterms. This is for secondary cvterms; primary cvterms should use stock.type_id.';


-- ================================================
-- TABLE: stock_cvtermprop
-- ================================================

create table stock_cvtermprop (
    stock_cvtermprop_id bigserial not null,
    primary key (stock_cvtermprop_id),
    stock_cvterm_id bigint not null,
    foreign key (stock_cvterm_id) references stock_cvterm (stock_cvterm_id) on delete cascade,
    type_id bigint not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint stock_cvtermprop_c1 unique (stock_cvterm_id,type_id,rank)
);
create index stock_cvtermprop_idx1 on stock_cvtermprop (stock_cvterm_id);
create index stock_cvtermprop_idx2 on stock_cvtermprop (type_id);

COMMENT ON TABLE stock_cvtermprop IS 'Extensible properties for
stock to cvterm associations. Examples: GO evidence codes;
qualifiers; metadata such as the date on which the entry was curated
and the source of the association. See the stockprop table for
meanings of type_id, value and rank.';

COMMENT ON COLUMN stock_cvtermprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. cvterms may come from the OBO evidence code cv.';

COMMENT ON COLUMN stock_cvtermprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';

COMMENT ON COLUMN stock_cvtermprop.rank IS 'Property-Value
ordering. Any stock_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used.';


-- ================================================
-- TABLE: stock_genotype
-- ================================================

create table stock_genotype (
       stock_genotype_id bigserial not null,
       primary key (stock_genotype_id),
       stock_id bigint not null,
       foreign key (stock_id) references stock (stock_id) on delete cascade,
       genotype_id bigint not null,
       foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
       constraint stock_genotype_c1 unique (stock_id, genotype_id)
);
create index stock_genotype_idx1 on stock_genotype (stock_id);
create index stock_genotype_idx2 on stock_genotype (genotype_id);

COMMENT ON TABLE stock_genotype IS 'Simple table linking a stock to
a genotype. Features with genotypes can be linked to stocks thru feature_genotype -> genotype -> stock_genotype -> stock.';


-- ================================================
-- TABLE: stockcollection
-- ================================================

create table stockcollection (
	stockcollection_id bigserial not null, 
        primary key (stockcollection_id),
	type_id bigint not null,
        foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
        contact_id bigint null,
        foreign key (contact_id) references contact (contact_id) on delete set null INITIALLY DEFERRED,
	name varchar(255),
	uniquename text not null,
	constraint stockcollection_c1 unique (uniquename,type_id)
);
create index stockcollection_name_ind1 on stockcollection (name);
create index stockcollection_idx1 on stockcollection (contact_id);
create index stockcollection_idx2 on stockcollection (type_id);
create index stockcollection_idx3 on stockcollection (uniquename);

COMMENT ON TABLE stockcollection IS 'The lab or stock center distributing the stocks in their collection.';
COMMENT ON COLUMN stockcollection.uniquename IS 'uniqename is the value of the collection cv.';
COMMENT ON COLUMN stockcollection.type_id IS 'type_id is the collection type cv.';
COMMENT ON COLUMN stockcollection.name IS 'name is the collection.';
COMMENT ON COLUMN stockcollection.contact_id IS 'contact_id links to the contact information for the collection.';


-- ================================================
-- TABLE: stockcollectionprop
-- ================================================

create table stockcollectionprop (
    stockcollectionprop_id bigserial not null,
    primary key (stockcollectionprop_id),
    stockcollection_id bigint not null,
    foreign key (stockcollection_id) references stockcollection (stockcollection_id) on delete cascade INITIALLY DEFERRED,
    type_id bigint not null,
    foreign key (type_id) references cvterm (cvterm_id),
    value text null,
    rank int not null default 0,
    cvalue_id bigint,
    FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    constraint stockcollectionprop_c1 unique (stockcollection_id,type_id,rank)
);
create index stockcollectionprop_idx1 on stockcollectionprop (stockcollection_id);
create index stockcollectionprop_idx2 on stockcollectionprop (type_id);
CREATE INDEX stockcollectionprop_idx3 ON stockcollectionprop (cvalue_id);

COMMENT ON TABLE stockcollectionprop IS 'The table stockcollectionprop
contains the value of the stock collection such as website/email URLs;
the value of the stock collection order URLs.';
COMMENT ON COLUMN stockcollectionprop.type_id IS 'The cv for the type_id is "stockcollection property type".';
COMMENT ON COLUMN stockcollectionprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

-- ================================================
-- TABLE: stockcollection_stock
-- ================================================

create table stockcollection_stock (
    stockcollection_stock_id bigserial not null,
    primary key (stockcollection_stock_id),
    stockcollection_id bigint not null,
    foreign key (stockcollection_id) references stockcollection (stockcollection_id) on delete cascade INITIALLY DEFERRED,
    stock_id bigint not null,
    foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
    constraint stockcollection_stock_c1 unique (stockcollection_id,stock_id)
);
create index stockcollection_stock_idx1 on stockcollection_stock (stockcollection_id);
create index stockcollection_stock_idx2 on stockcollection_stock (stock_id);

COMMENT ON TABLE stockcollection_stock IS 'stockcollection_stock links
a stock collection to the stocks which are contained in the collection.';



-- ================================================
-- TABLE: stock_dbxrefprop
-- ================================================

create table stock_dbxrefprop (
       stock_dbxrefprop_id bigserial not null,
       primary key (stock_dbxrefprop_id),
       stock_dbxref_id bigint not null,
       foreign key (stock_dbxref_id) references stock_dbxref (stock_dbxref_id) on delete cascade INITIALLY DEFERRED,
       type_id bigint not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       value text null,
       rank int not null default 0,
       constraint stock_dbxrefprop_c1 unique (stock_dbxref_id,type_id,rank)
);
create index stock_dbxrefprop_idx1 on stock_dbxrefprop (stock_dbxref_id);
create index stock_dbxrefprop_idx2 on stock_dbxrefprop (type_id);

COMMENT ON TABLE stock_dbxrefprop IS 'A stock_dbxref can have any number of
slot-value property tags attached to it. This is useful for storing properties related to dbxref annotations of stocks, such as evidence codes, and references, and metadata, such as create/modify dates. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, stock_dbxrefprop_c1, for
the combination of stock_dbxref_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.';

-- ================================================
-- TABLE: stockcollection_db
-- ================================================

CREATE TABLE stockcollection_db (
    stockcollection_db_id bigserial primary key NOT NULL,
    stockcollection_id bigint NOT NULL,
    db_id bigint NOT NULL,
    CONSTRAINT stockcollection_db_c1 UNIQUE (stockcollection_id, db_id),
    FOREIGN KEY (db_id) REFERENCES db(db_id) ON DELETE CASCADE,
    FOREIGN KEY (stockcollection_id) REFERENCES stockcollection(stockcollection_id) ON DELETE CASCADE
);

CREATE INDEX stockcollection_db_idx1 ON stockcollection_db USING btree (stockcollection_id);
CREATE INDEX stockcollection_db_idx2 ON stockcollection_db USING btree (db_id);

COMMENT ON TABLE stockcollection_db IS 'Stock collections may be respresented 
by an external online database. This table associates a stock collection with 
a database where its member stocks can be found. Individual stock that are part 
of this collction should have entries in the stock_dbxref table with the same 
db_id record';


-- ================================================
-- TABLE: stock_feature
-- ================================================

CREATE TABLE stock_feature (
  stock_feature_id bigserial NOT NULL,
  feature_id bigint NOT NULL,
  stock_id bigint NOT NULL,
  type_id bigint NOT NULL,
  rank INT NOT NULL DEFAULT 0,
  PRIMARY KEY (stock_feature_id),
  FOREIGN KEY (feature_id) REFERENCES feature (feature_id) ON DELETE CASCADE INITIALLY DEFERRED,
  FOREIGN KEY (stock_id) REFERENCES stock (stock_id) ON DELETE CASCADE INITIALLY DEFERRED,
  FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE CASCADE INITIALLY DEFERRED,
  CONSTRAINT stock_feature_c1 UNIQUE (feature_id, stock_id, type_id, rank)  
);
create index stock_feature_idx1 on stock_feature (stock_feature_id);
create index stock_feature_idx2 on stock_feature (feature_id);
create index stock_feature_idx3 on stock_feature (stock_id);
create index stock_feature_idx4 on stock_feature (type_id);

COMMENT ON TABLE stock_feature  IS 'Links a stock to a feature.';


-- ================================================
-- TABLE: stock_featuremap
-- ================================================

CREATE TABLE stock_featuremap (
  stock_featuremap_id bigserial NOT NULL,
  featuremap_id bigint NOT NULL,
  stock_id bigint NOT NULL,
  type_id bigint,
  PRIMARY KEY (stock_featuremap_id),
  FOREIGN KEY (featuremap_id) REFERENCES featuremap (featuremap_id) ON DELETE CASCADE INITIALLY DEFERRED,
  FOREIGN KEY (stock_id) REFERENCES stock (stock_id)  ON DELETE CASCADE INITIALLY DEFERRED,
  FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE CASCADE INITIALLY DEFERRED,
  CONSTRAINT stock_featuremap_c1 UNIQUE (featuremap_id, stock_id, type_id)  
);

create index stock_featuremap_idx1 on stock_featuremap (featuremap_id);
create index stock_featuremap_idx2 on stock_featuremap (stock_id);
create index stock_featuremap_idx3 on stock_featuremap (type_id);

COMMENT ON TABLE stock_featuremap  IS 'Links a featuremap to a stock.';


-- ================================================
-- TABLE: stock_library
-- ================================================
CREATE TABLE stock_library (
    stock_library_id bigserial primary key NOT NULL,
    library_id bigint NOT NULL,
    stock_id bigint NOT NULL,
    CONSTRAINT stock_library_c1 UNIQUE (library_id, stock_id),
    FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE,
    FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE
);

CREATE INDEX stock_library_idx1 ON stock_library USING btree (library_id);
CREATE INDEX stock_library_idx2 ON stock_library USING btree (stock_id);

COMMENT ON TABLE stock_library IS 'Links a stock with a library.';

