
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '> <')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserRankedComments AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.TagsArray,
        COALESCE(SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS UserCommentCount,
        COALESCE(SUM(CASE WHEN c.UserId IS NOT NULL AND c.UserDisplayName IS NOT NULL THEN 1 ELSE 0 END), 0) AS ValidCommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostID = c.PostId
    GROUP BY 
        rp.PostID, rp.Title, rp.TagsArray
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    SUM(uc.UserCommentCount) AS TotalUserComments,
    AVG(uc.ValidCommentCount) AS AverageValidComments,
    ARRAY_AGG(DISTINCT uc.TagsArray) AS UniqueTags
FROM 
    Users up
JOIN 
    UserRankedComments uc ON up.Id = (SELECT OwnerUserId FROM Posts WHERE Id = uc.PostID)
GROUP BY 
    up.Id, up.DisplayName
HAVING 
    SUM(uc.UserCommentCount) > 0
ORDER BY 
    TotalUserComments DESC
LIMIT 10;
