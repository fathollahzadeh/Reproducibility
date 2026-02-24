
WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 5  
),
HighEngagementPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes  
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title
),
EngagementStats AS (
    SELECT 
        hp.PostId,
        hp.Title,
        hp.CommentCount,
        hp.UpVotes,
        hp.DownVotes,
        CASE 
            WHEN hp.CommentCount > 10 AND hp.UpVotes > 20 THEN 'Highly Engaging'
            WHEN hp.CommentCount > 5 AND hp.UpVotes > 10 THEN 'Moderately Engaging'
            ELSE 'Less Engaging'
        END AS EngagementLevel
    FROM 
        HighEngagementPosts hp
),
Results AS (
    SELECT 
        tt.TagName,
        ae.Title,
        ae.CommentCount,
        ae.UpVotes,
        ae.DownVotes,
        ae.EngagementLevel
    FROM 
        TopTags tt
    JOIN 
        EngagementStats ae ON ae.Title LIKE '%' || tt.TagName || '%'  
)
SELECT 
    TagName,
    COUNT(*) AS TotalEngagedPosts,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(UpVotes) AS AvgUpVotes,
    AVG(DownVotes) AS AvgDownVotes
FROM 
    Results
GROUP BY 
    TagName
ORDER BY 
    TotalEngagedPosts DESC
LIMIT 10;
