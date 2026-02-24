WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
CommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
VoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    COALESCE(vc.UpVotes, 0) AS UpVotes,
    COALESCE(vc.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN rp.Score > 100 THEN 'Highly Rated'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentCounts cc ON rp.Id = cc.PostId
LEFT JOIN 
    VoteCounts vc ON rp.Id = vc.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC;