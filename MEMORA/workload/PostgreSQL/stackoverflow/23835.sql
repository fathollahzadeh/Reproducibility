WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
ActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.UpVotes,
        ua.DownVotes,
        ua.PostCount,
        ua.TotalViews,
        ua.AvgScore,
        RANK() OVER (PARTITION BY ua.UpVotes - ua.DownVotes ORDER BY ua.TotalViews DESC) AS ActivityRank
    FROM 
        UserActivity ua
    WHERE 
        ua.PostCount > 0
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        UpVotes, 
        DownVotes,
        TotalViews,
        AvgScore,
        ActivityRank
    FROM 
        ActiveUsers
    WHERE 
        ActivityRank <= 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        tu.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        TopUsers tu ON p.OwnerUserId = tu.UserId
    WHERE 
        rp.RecentPostRank <= 5
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.CommentCount,
    pd.OwnerDisplayName,
    pd.UpVoteCount,
    pd.DownVoteCount
FROM 
    PostDetails pd
WHERE
    pd.ViewCount > 100
ORDER BY 
    pd.ViewCount DESC,
    pd.Score DESC;