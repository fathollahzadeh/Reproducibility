
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Owner,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
        AND p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RecentPosts
    GROUP BY 
        TagName
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS QuestionsPosted
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        SUM(TagCount) AS TotalUsage
    FROM 
        TagStatistics
    GROUP BY 
        TagName
    ORDER BY 
        TotalUsage DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Owner,
    t.TagName,
    tu.DisplayName AS TopUser,
    tu.UpVotes,
    tu.DownVotes,
    tu.QuestionsPosted
FROM 
    RecentPosts rp
JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
JOIN 
    TopTags t ON t.TagName = ANY(string_to_array(rp.Tags, '><'))
JOIN 
    TopUsers tu ON rp.Owner = tu.DisplayName
WHERE 
    ph.CreationDate >= rp.CreationDate
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
