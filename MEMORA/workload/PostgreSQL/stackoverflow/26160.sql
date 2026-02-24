
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        ARRAY_AGG(pt.TagName) AS RelatedTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PopularTags pt ON pt.TagName = ANY(string_to_array(rp.Tags, '>'))
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName
),
FinalOutput AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.OwnerDisplayName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 2) AS TotalUpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 3) AS TotalDownVotes,
        (SELECT AVG(Score) FROM Posts WHERE OwnerUserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)) AS AvgOwnerScore,
        ps.RelatedTags
    FROM 
        PostStatistics ps
)
SELECT 
    *
FROM 
    FinalOutput
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50;
