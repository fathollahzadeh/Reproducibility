WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - interval '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.UpVoteCount + rp.DownVoteCount = 0 THEN NULL 
            ELSE ROUND((CAST(rp.UpVoteCount AS DECIMAL) / (rp.UpVoteCount + rp.DownVoteCount)) * 100, 2) 
        END AS UpvotePercentage
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
)
SELECT 
    fp.OwnerUserId,
    u.DisplayName,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.UpvotePercentage,
    CASE 
        WHEN fp.UpvotePercentage IS NULL THEN 'No Votes'
        WHEN fp.UpvotePercentage > 75 THEN 'High Engagement'
        WHEN fp.UpvotePercentage BETWEEN 50 AND 75 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.OwnerUserId = u.Id
WHERE 
    u.Reputation > 1000
ORDER BY 
    fp.CommentCount DESC, 
    fp.UpVoteCount DESC
FETCH FIRST 10 ROWS ONLY;