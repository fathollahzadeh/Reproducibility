
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
PostStats AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top' 
            WHEN rp.Rank <= 5 THEN 'High' 
            ELSE 'Low' 
        END AS Popularity
    FROM
        RankedPosts rp
),
VoteData AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
)
SELECT
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    COALESCE(vd.UpVotes, 0) AS UpVotes,
    COALESCE(vd.DownVotes, 0) AS DownVotes,
    CASE
        WHEN ps.Popularity = 'Top' AND ps.CommentCount > 5 THEN 'Engaging'
        WHEN ps.Popularity = 'High' AND ps.Score > 100 THEN 'Highly Engaging'
        ELSE 'Needs Improvement'
    END AS EngagementLevel,
    CASE
        WHEN EXISTS (
            SELECT 1 
            FROM Badges b 
            WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId) 
            AND b.Class = 1 
        ) THEN 'Gold Member'
        WHEN EXISTS (
            SELECT 1 
            FROM Badges b 
            WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId) 
            AND b.Class = 2 
        ) THEN 'Silver Member'
        ELSE 'Regular User'
    END AS UserMembershipLevel
FROM
    PostStats ps
LEFT JOIN VoteData vd ON ps.PostId = vd.PostId
WHERE
    ps.ViewCount > 10
ORDER BY
    ps.Score DESC, ps.CommentCount DESC
LIMIT 100;
