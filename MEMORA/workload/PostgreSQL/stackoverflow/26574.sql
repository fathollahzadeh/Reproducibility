
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY COUNT(DISTINCT v.UserId) DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate, 
        CommentCount, 
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
),
PostStatistics AS (
    SELECT 
        COUNT(PostId) AS TotalPosts,
        AVG(CommentCount) AS AvgComments,
        AVG(VoteCount) AS AvgVotes
    FROM 
        FilteredPosts
)
SELECT 
    f.OwnerDisplayName,
    f.Title,
    f.CommentCount,
    f.VoteCount,
    ps.TotalPosts,
    ps.AvgComments,
    ps.AvgVotes
FROM 
    FilteredPosts f
CROSS JOIN 
    PostStatistics ps
ORDER BY 
    f.VoteCount DESC;
