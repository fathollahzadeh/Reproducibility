WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
    GROUP BY 
        OwnerDisplayName
    HAVING 
        COUNT(*) >= 3
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        RecentVotes rv ON p.Id = rv.PostId
)
SELECT 
    pu.OwnerDisplayName,
    COUNT(pd.Id) AS RecentPostCount,
    SUM(pd.UpVotes) AS TotalUpVotes,
    SUM(pd.DownVotes) AS TotalDownVotes
FROM 
    TopUsers pu
JOIN 
    PostDetails pd ON pu.OwnerDisplayName = pd.OwnerDisplayName
GROUP BY 
    pu.OwnerDisplayName
ORDER BY 
    TotalUpVotes DESC, RecentPostCount DESC;