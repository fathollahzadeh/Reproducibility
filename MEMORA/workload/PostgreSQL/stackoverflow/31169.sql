WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(vv.UpVotes, 0) - COALESCE(vv.DownVotes, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(vv.UpVotes, 0) - COALESCE(vv.DownVotes, 0) DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN 
        (SELECT
            PostId,
            COUNT(*) AS CommentCount
         FROM
            Comments
         GROUP BY
            PostId) pc ON p.Id = pc.PostId
    LEFT JOIN 
        (SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM
            Votes
         GROUP BY
            PostId) vv ON p.Id = vv.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Author,
    rp.CommentCount,
    rp.Score
FROM
    RankedPosts rp
WHERE
    (rp.PostRank <= 5 OR rp.CommentCount > 10)  
ORDER BY
    rp.Score DESC;