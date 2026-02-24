
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopQuestions AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
VoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        tq.Title,
        tq.OwnerDisplayName AS Creator,
        tq.CreationDate,
        tq.ViewCount,
        tq.Score,
        vs.UpVotes,
        vs.DownVotes,
        (vs.UpVotes - vs.DownVotes) AS NetVotes
    FROM 
        TopQuestions tq
    JOIN 
        VoteStatistics vs ON tq.Id = vs.PostId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.UpVotes,
    p.DownVotes,
    p.NetVotes,
    ROW_NUMBER() OVER (ORDER BY p.NetVotes DESC, p.Score DESC) AS Rank
FROM 
    PostDetails p
ORDER BY 
    p.NetVotes DESC, p.Score DESC;
