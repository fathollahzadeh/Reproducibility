
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
HighRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        Author,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        VoteRank <= 10
),
TagCounts AS (
    SELECT 
        UNNEST(string_to_array(TRIM(BOTH '<>' FROM Tags), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        HighRankedPosts
    GROUP BY 
        TagName
)
SELECT
    tc.TagName,
    tc.PostCount,
    COUNT(DISTINCT hrp.PostId) AS HighRankedPostCount,
    AVG(hrp.CommentCount) AS AvgComments,
    SUM(hrp.VoteCount) AS TotalVotes
FROM 
    TagCounts tc
JOIN 
    HighRankedPosts hrp ON hrp.Tags LIKE '%' || tc.TagName || '%'
GROUP BY 
    tc.TagName, tc.PostCount
ORDER BY 
    TotalVotes DESC, HighRankedPostCount DESC;
