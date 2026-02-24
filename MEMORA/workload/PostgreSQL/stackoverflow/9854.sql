WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
),
EnhancedPosts AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.Score,
        trp.ViewCount,
        trp.OwnerDisplayName,
        pv.VoteCount,
        pv.UpVotes,
        pv.DownVotes
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        PostVotes pv ON trp.PostId = pv.PostId
)
SELECT 
    ep.PostId,
    ep.Title,
    ep.CreationDate,
    ep.Score,
    ep.ViewCount,
    ep.OwnerDisplayName,
    ep.VoteCount,
    ep.UpVotes,
    ep.DownVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ep.PostId) AS CommentCount
FROM 
    EnhancedPosts ep
ORDER BY 
    ep.Score DESC, ep.ViewCount DESC;