WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVotes,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVotes,
        RANK() OVER (PARTITION BY p.Tags ORDER BY (COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') - COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod')) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),

TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT rp.PostId) AS PostCount,
        SUM(rp.CommentCount) AS TotalComments,
        AVG(rp.UpVotes) AS AverageUpVotes,
        AVG(rp.DownVotes) AS AverageDownVotes,
        MAX(rp.Rank) AS MaxRank
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        RankedPosts rp ON p.Id = rp.PostId
    GROUP BY 
        t.TagName
),

FinalStatistics AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.TotalComments,
        ts.AverageUpVotes,
        ts.AverageDownVotes,
        CASE 
            WHEN ts.MaxRank IS NOT NULL THEN 'Active' 
            ELSE 'Inactive' 
        END AS TagStatus
    FROM 
        TagStatistics ts
)

SELECT 
    fs.TagName,
    fs.PostCount,
    fs.TotalComments,
    fs.AverageUpVotes,
    fs.AverageDownVotes,
    fs.TagStatus
FROM 
    FinalStatistics fs
ORDER BY 
    fs.PostCount DESC, fs.TotalComments DESC;
