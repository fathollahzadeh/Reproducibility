WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
),
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CreationDate,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.OwnerDisplayName, rp.CreationDate
),
PostsWithScores AS (
    SELECT 
        pwc.PostId,
        pwc.Title,
        pwc.Score,
        pwc.OwnerDisplayName,
        pwc.CreationDate,
        pwc.CommentCount,
        CASE 
            WHEN pwc.CommentCount > 10 THEN 'High Engagement'
            WHEN pwc.CommentCount BETWEEN 1 AND 10 THEN 'Moderate Engagement'
            ELSE 'No Engagement'
        END AS EngagementLevel
    FROM 
        PostWithComments pwc
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.CommentCount,
    ps.EngagementLevel,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes
FROM 
    PostsWithScores ps
LEFT JOIN 
    (SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
     FROM 
        Votes 
     GROUP BY 
        PostId) v ON ps.PostId = v.PostId
WHERE 
    ps.EngagementLevel <> 'No Engagement'
ORDER BY 
    ps.Score DESC, ps.CommentCount DESC
LIMIT 50;