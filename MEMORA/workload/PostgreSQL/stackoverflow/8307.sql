
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate
),
TopRankedPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Rank,
        CASE 
            WHEN rp.PostTypeId = 1 THEN 'Question'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    trp.PostId, 
    trp.Title, 
    trp.PostCategory,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = trp.PostId AND v.VoteTypeId IN (2, 3)) AS TotalVotes,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId IN (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Id = trp.PostId)) AS BadgeCount
FROM 
    TopRankedPosts trp
ORDER BY 
    trp.Rank, trp.Title;
