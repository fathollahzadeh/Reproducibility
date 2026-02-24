WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    AND 
        p.Score > 0 
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CreationDate, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
PostVotes AS (
    SELECT 
        p.Id AS PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
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
    trp.Title, 
    trp.OwnerDisplayName, 
    trp.Score, 
    trp.CreationDate, 
    pv.UpVotes, 
    pv.DownVotes,
    (pv.UpVotes - pv.DownVotes) AS NetScore
FROM 
    TopRankedPosts trp
JOIN 
    PostVotes pv ON trp.PostId = pv.PostId
ORDER BY 
    NetScore DESC, 
    trp.Score DESC;