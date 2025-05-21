(local HashMap {})
(set HashMap.__index HashMap)

(fn HashMap.new [?tbl]
  "Create a new instance of `HashMap` with optional `?tbl`.
@param ?tbl table An optional table to construct the initial map.
@return HashMap"
  (let [self (setmetatable {} HashMap)]
    (assert (or (= nil ?tbl) (= :table (type ?tbl)))
            "Expected `nil` or a table, got " (type ?tbl))
    (set self._hash_map (or ?tbl {}))
    self))

(fn HashMap.insert! [self key value]
  "Add `value` at `key`. If any value is already stored at the `key`, overwrite
it.
@param key any except `nil`
@param value any"
  (tset self._hash_map key value))

(fn HashMap.or-insert! [self key value]
  "Add `value` at `key`. If any value is already stored at the `key`, do nothing.
@param key string"
  (when (= nil (self:get key))
    (tset self._hash_map key value)))

(λ HashMap.get [self key]
  "Return value stored at `key`.
@param key any except `nil`
@return any"
  (. self._hash_map key))

(fn HashMap.contains? [self key]
  "Check if `key` exists in the map.
@param key any except `nil`
@return boolean"
  (if (self:get key)
      true
      false))

(fn HashMap.keys [self]
  "Return all the keys stored in the map.
@return any[]"
  (icollect [key (pairs self._hash_map)]
    key))

(fn HashMap.values [self]
  "Return all the values stored in the map.
@return any[]"
  (icollect [_key val (pairs self._hash_map)]
    val))

(fn HashMap.clear! [self]
  "Clear the map."
  (set self._hidden-map self._hash_map)
  (set self._hash_map {}))

(fn HashMap.restore! [self]
  "Restore once cleared map."
  (assert self._hidden-map "The map is not cleared.")
  (set self._hash_map self._hidden-map)
  (set self._hidden-map nil))

HashMap
