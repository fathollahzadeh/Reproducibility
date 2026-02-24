WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(DISTINCT v.Id) DESC) AS TagRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        REGEXP_REPLACE(rp.Tags, '[<>]', '', 'g') AS CleanedTags
    FROM RankedPosts rp
    WHERE rp.TagRank <= 3 
),
StringProcessing AS (
    SELECT 
        PostId,
        Title,
        Body,
        OwnerDisplayName,
        CommentCount,
        UpvoteCount,
        DownvoteCount,
        ARRAY_LENGTH(STRING_TO_ARRAY(CleanedTags, ','), 1) AS TagCount,
        LOWER(Title) AS LowercaseTitle,
        UPPER(OwnerDisplayName) AS UppercaseOwner,
        LENGTH(Body) AS BodyLength
    FROM TopRankedPosts
)
SELECT 
    SP.PostId,
    SP.Title,
    SP.Body,
    SP.OwnerDisplayName,
    SP.CommentCount,
    SP.UpvoteCount,
    SP.DownvoteCount,
    SP.TagCount,
    SP.LowercaseTitle,
    SP.UppercaseOwner,
    SP.BodyLength
FROM StringProcessing SP
ORDER BY SP.UpvoteCount DESC, SP.CommentCount DESC;