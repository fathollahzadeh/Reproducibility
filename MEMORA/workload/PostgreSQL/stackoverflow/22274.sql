
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.Tags
),
UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS TotalPosts,
        COALESCE(AVG(rp.Score), 0) AS AvgScore,
        COALESCE(SUM(rp.UpVotes) - SUM(rp.DownVotes), 0) AS NetVotes,
        CASE 
            WHEN COUNT(rp.PostId) > 0 THEN (SUM(rp.Score) / COUNT(rp.PostId))
            ELSE NULL
        END AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
HighScorers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        AvgScore, 
        NetVotes, 
        AvgPostScore,
        LEAD(AvgPostScore, 1) OVER (ORDER BY AvgPostScore DESC) AS NextAvgPostScore
    FROM 
        UserPostStatistics
    WHERE 
        AvgPostScore IS NOT NULL
),
PostHistoryRecent AS (
    SELECT 
        ph.UserId, 
        ph.PostId, 
        ph.CreationDate, 
        ph.PostHistoryTypeId,
        p.Title,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= DATE '2024-10-01' - INTERVAL '1 month'
        AND ph.PostHistoryTypeId IN (10, 11, 12, 13)
)
SELECT 
    upp.UserId,
    upp.DisplayName,
    upp.TotalPosts,
    upp.AvgScore,
    upp.NetVotes,
    COALESCE(hs.NextAvgPostScore, 0) AS NextAvgScore,
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    ph.Comment
FROM 
    UserPostStatistics upp
LEFT JOIN 
    HighScorers hs ON upp.UserId = hs.UserId
LEFT JOIN 
    PostHistoryRecent ph ON upp.UserId = ph.UserId
WHERE 
    upp.TotalPosts > 0
ORDER BY 
    upp.AvgPostScore DESC, 
    ph.CreationDate DESC
LIMIT 50;
