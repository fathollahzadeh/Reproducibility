WITH RankedPostVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER(PARTITION BY p.Id ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
), 
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10  
), 
CommentsWithKeywords AS (
    SELECT 
        c.PostId,
        c.Text,
        c.CreationDate,
        SUM(CASE 
            WHEN LOWER(c.Text) LIKE '%help%' THEN 1 
            ELSE 0 
        END) AS HelpKeywordCount,
        SUM(CASE 
            WHEN LOWER(c.Text) LIKE '%issue%' THEN 1 
            ELSE 0 
        END) AS IssueKeywordCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId, c.Text, c.CreationDate
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    pv.VoteCount,
    tt.TagName,
    cwk.Text AS CommentText,
    cwk.HelpKeywordCount,
    cwk.IssueKeywordCount
FROM 
    Posts p
JOIN 
    RankedPostVotes pv ON p.Id = pv.PostId
JOIN 
    PostLinks pl ON p.Id = pl.PostId
JOIN 
    PopularTags tt ON tt.TagName IN (SELECT UNNEST(string_to_array(p.Tags, '><')))
LEFT JOIN 
    CommentsWithKeywords cwk ON cwk.PostId = p.Id
WHERE 
    pv.VoteRank = 1 
ORDER BY 
    pv.VoteCount DESC, p.CreationDate DESC;