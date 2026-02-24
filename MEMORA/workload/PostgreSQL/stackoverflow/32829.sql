WITH RECURSIVE TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) as UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
PostApproval AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        p.Id,
        COUNT(ph.Id) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        p.Id
)
SELECT 
    tu.UserRank,
    tu.DisplayName AS TopUser,
    pa.PostId,
    pa.Title AS PostTitle,
    pa.Score,
    pa.CommentCount,
    phs.EditCount,
    phs.FirstEditDate,
    phs.LastEditDate,
    pa.LastVoteDate,
    pa.UpVoteCount,
    pa.DownVoteCount,
    CASE 
        WHEN (pa.UpVoteCount - pa.DownVoteCount) > 0 THEN 'Positive'
        WHEN (pa.UpVoteCount - pa.DownVoteCount) < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopUsers tu
LEFT JOIN 
    PostApproval pa ON tu.Id = pa.OwnerUserId
LEFT JOIN 
    PostHistorySummary phs ON pa.PostId = phs.Id
WHERE 
    tu.UserRank <= 10 
ORDER BY 
    tu.UserRank, pa.Score DESC;