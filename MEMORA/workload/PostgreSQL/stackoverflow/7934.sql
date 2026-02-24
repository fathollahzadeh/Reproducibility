
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
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
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName, p.CreationDate, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    (rp.UpvoteCount - rp.DownvoteCount) AS NetVotes,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top'
        ELSE 'Others'
    END AS RankCategory
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10 OR (rp.Rank > 10 AND (rp.UpvoteCount - rp.DownvoteCount) > 0)
ORDER BY 
    RankCategory, NetVotes DESC, rp.CreationDate DESC;
