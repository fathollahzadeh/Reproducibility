
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.CreationDate DESC) AS YearRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        Id, 
        Title, 
        CreationDate, 
        OwnerDisplayName, 
        Score, 
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        YearRank <= 5 
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 10 THEN 1 END) AS Deletions
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(vs.Deletions, 0) AS Deletions,
    CASE 
        WHEN COALESCE(vs.Deletions, 0) > 0 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN tp.ViewCount > 1000 THEN 'Hot'
        ELSE 'Normal'
    END AS Popularity
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteSummary vs ON tp.Id = vs.PostId
ORDER BY 
    tp.CreationDate DESC;
