WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        Tag
),
VotingStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.OwnerDisplayName,
    ts.Tag,
    ts.TagCount,
    vs.UpVotes,
    vs.DownVotes,
    rp.PostRank
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON ts.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '><'))
JOIN 
    VotingStats vs ON rp.PostId = vs.PostId
WHERE 
    rp.PostRank = 1  
ORDER BY 
    ts.TagCount DESC, rp.CreationDate DESC;