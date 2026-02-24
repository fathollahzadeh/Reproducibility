WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(pv.VoteCount, 0) AS VoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) pv ON p.Id = pv.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.VoteCount,
        rp.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation
    FROM 
        RecursivePostCTE rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        u.Reputation >= 1000 
        AND rp.CommentCount > 5
        AND rp.rn <= 3
),
RankedPosts AS (
    SELECT 
        fp.*,
        RANK() OVER (ORDER BY fp.VoteCount DESC, fp.CreationDate DESC) AS PostRank
    FROM 
        FilteredPosts fp
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.VoteCount,
    rp.CommentCount,
    rp.Reputation,
    CASE 
        WHEN rp.VoteCount IS NULL THEN 'No Votes'
        ELSE 'Has Votes'
    END AS VoteStatus
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.VoteCount DESC;
