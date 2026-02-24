
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        u.Views,
        (u.Views + u.UpVotes - u.DownVotes) AS EngagementScore
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        EngagementScore,
        ROW_NUMBER() OVER (ORDER BY EngagementScore DESC) AS Rank
    FROM 
        UserStats
    WHERE 
        EngagementScore > 100
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Body, p.ViewCount
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        u.DisplayName AS AuthorName,
        u.Reputation AS AuthorReputation,
        ts.Rank AS TopUserRank
    FROM 
        RecentPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        TopUsers ts ON u.Id = ts.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.AuthorName,
    pd.AuthorReputation,
    pd.ViewCount,
    pd.CommentCount,
    pd.VoteCount,
    COALESCE(pd.TopUserRank, 999) AS TopUserRank 
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0 
ORDER BY 
    pd.ViewCount DESC, 
    pd.VoteCount DESC;
