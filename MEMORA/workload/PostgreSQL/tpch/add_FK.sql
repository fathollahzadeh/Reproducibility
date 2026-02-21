-- CUSTOMER
ALTER TABLE customer
  ADD CONSTRAINT fk_customer_nation
  FOREIGN KEY (c_nationkey) REFERENCES nation(n_nationkey);

-- ORDERS
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_customer
  FOREIGN KEY (o_custkey) REFERENCES customer(c_custkey);

-- LINEITEM
ALTER TABLE lineitem
  ADD CONSTRAINT fk_lineitem_orders
  FOREIGN KEY (l_orderkey) REFERENCES orders(o_orderkey);

ALTER TABLE lineitem
  ADD CONSTRAINT fk_lineitem_part
  FOREIGN KEY (l_partkey) REFERENCES part(p_partkey);

ALTER TABLE lineitem
  ADD CONSTRAINT fk_lineitem_supplier
  FOREIGN KEY (l_suppkey) REFERENCES supplier(s_suppkey);

-- SUPPLIER
ALTER TABLE supplier
  ADD CONSTRAINT fk_supplier_nation
  FOREIGN KEY (s_nationkey) REFERENCES nation(n_nationkey);

-- PARTSUPP
ALTER TABLE partsupp
  ADD CONSTRAINT fk_partsupp_part
  FOREIGN KEY (ps_partkey) REFERENCES part(p_partkey);

ALTER TABLE partsupp
  ADD CONSTRAINT fk_partsupp_supplier
  FOREIGN KEY (ps_suppkey) REFERENCES supplier(s_suppkey);

-- NATION
ALTER TABLE nation
  ADD CONSTRAINT fk_nation_region
  FOREIGN KEY (n_regionkey) REFERENCES region(r_regionkey);


ALTER TABLE lineitem VALIDATE CONSTRAINT fk_lineitem_orders;
