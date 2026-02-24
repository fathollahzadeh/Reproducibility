WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate, 
        p.Tags, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.ViewCount > 100  
),
SelectedPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.ViewCount, 
        rp.CreationDate, 
        rp.Tags, 
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  
),
RecentVotes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    sp.PostId, 
    sp.Title, 
    sp.ViewCount, 
    sp.CreationDate, 
    sp.Tags, 
    sp.OwnerDisplayName, 
    rv.UpVotesCount, 
    rv.DownVotesCount
FROM 
    SelectedPosts sp
LEFT JOIN 
    RecentVotes rv ON sp.PostId = rv.PostId
ORDER BY 
    sp.ViewCount DESC, 
    sp.CreationDate ASC;