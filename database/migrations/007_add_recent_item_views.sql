BEGIN;

ALTER TABLE search_history
    ADD COLUMN item_code INTEGER REFERENCES items(item_code) ON DELETE CASCADE,
    ADD COLUMN last_viewed_at TIMESTAMPTZ;

UPDATE search_history sh
   SET item_code = (
           SELECT i.item_code
             FROM items i
            WHERE UPPER(TRIM(i.item)) = UPPER(TRIM(sh.query))
            ORDER BY i.item_code
            LIMIT 1
       ),
       last_viewed_at = sh.searched_at
 WHERE EXISTS (
       SELECT 1 FROM items i
        WHERE UPPER(TRIM(i.item)) = UPPER(TRIM(sh.query))
   );

DELETE FROM search_history older
 USING search_history newer
 WHERE older.user_id = newer.user_id
   AND older.item_code = newer.item_code
   AND older.item_code IS NOT NULL
   AND (older.last_viewed_at, older.search_history_id)
       < (newer.last_viewed_at, newer.search_history_id);

CREATE UNIQUE INDEX idx_search_history_user_item
    ON search_history (user_id, item_code)
    WHERE item_code IS NOT NULL;

CREATE INDEX idx_search_history_recent_views
    ON search_history (user_id, last_viewed_at DESC)
    WHERE item_code IS NOT NULL;

COMMIT;
