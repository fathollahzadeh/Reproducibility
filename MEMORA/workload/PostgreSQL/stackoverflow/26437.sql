
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(1) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS Tag(t) ON true
    JOIN 
        Tags t ON t.TagName = Tag.t
    GROUP BY 
        p.Id
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Score
),
PostAnalytics AS (
    SELECT 
        pt.PostId,
        pt.TagCount,
        pt.TagsList,
        ps.UpVotes,
        ps.DownVotes,
        ps.NetVotes,
        ps.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate
    FROM 
        PostTagCounts pt
    JOIN 
        PostScores ps ON pt.PostId = ps.PostId
    JOIN 
        Posts p ON pt.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    pa.OwnerDisplayName,
    pa.CreationDate,
    pa.Score,
    pa.TagCount,
    pa.TagsList,
    pa.UpVotes,
    pa.DownVotes,
    pa.NetVotes,
    RANK() OVER (ORDER BY pa.NetVotes DESC) AS Rank
FROM 
    PostAnalytics pa
WHERE 
    pa.TagCount > 3 AND pa.Score > 0
ORDER BY 
    pa.NetVotes DESC, pa.Score DESC 
LIMIT 10;
