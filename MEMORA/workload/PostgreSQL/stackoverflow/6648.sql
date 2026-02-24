
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
), 
AverageVoteStats AS (
    SELECT 
        PostId,
        AVG(Score) AS AvgScore,
        AVG(CommentCount) AS AvgComments
    FROM 
        RankedPosts
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    avs.AvgScore,
    avs.AvgComments
FROM 
    RankedPosts rp
JOIN 
    AverageVoteStats avs ON rp.PostId = avs.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC;
