
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Votes WHERE PostId = rp.PostId AND VoteTypeId = 1) AS AcceptedVotes,
        (SELECT COUNT(*) FROM Badges WHERE UserId = rp.OwnerUserId AND Class = 1) AS GoldBadgeCount
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.Score,
    fp.AcceptedVotes,
    fp.GoldBadgeCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CommentCount DESC;
