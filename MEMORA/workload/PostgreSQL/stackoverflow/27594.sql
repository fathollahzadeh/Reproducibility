WITH RankedPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.Body,
        Posts.Tags,
        Users.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN Votes.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN Votes.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN Comments.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY Posts.OwnerUserId ORDER BY COUNT(Votes.Id) DESC) AS OwnerRank
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.Body, Posts.Tags, Users.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        UpVoteCount,
        DownVoteCount,
        CommentCount,
        OwnerRank
    FROM 
        RankedPosts
    WHERE 
        OwnerRank <= 3
),
ProcessedTags AS (
    SELECT 
        PostId,
        UNNEST(string_to_array(Tags, ',')) AS Tag
    FROM 
        TopPosts
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.CommentCount,
    STRING_AGG(DISTINCT p.Tag, ', ') AS DistinctTags
FROM 
    TopPosts tp
JOIN 
    ProcessedTags p ON tp.PostId = p.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.OwnerDisplayName, tp.UpVoteCount, tp.DownVoteCount, tp.CommentCount
ORDER BY 
    tp.UpVoteCount DESC, tp.PostId ASC;
