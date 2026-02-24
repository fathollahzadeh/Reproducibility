
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        ph.UserId,
        COUNT(ph.Id) AS HistoryCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
),
CombinedResults AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ue.UpVotesReceived, 0) AS TotalUpVotes,
        COALESCE(ue.DownVotesReceived, 0) AS TotalDownVotes,
        COALESCE(up.RankPerUser, NULL) AS PostRank,
        COALESCE(ps.HistoryCount, 0) AS PostHistoryCount,
        COALESCE(ps.CloseReopenCount, 0) AS CloseReopenCount
    FROM 
        Users u
    LEFT JOIN 
        UserEngagement ue ON u.Id = ue.UserId
    LEFT JOIN 
        RankedPosts up ON u.Id = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = up.PostId)
    LEFT JOIN 
        PostHistoryStats ps ON u.Id = ps.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalUpVotes,
    TotalDownVotes,
    PostRank,
    PostHistoryCount,
    CloseReopenCount
FROM 
    CombinedResults
WHERE 
    (TotalUpVotes - TotalDownVotes) > 10
    OR PostHistoryCount > 5
ORDER BY 
    TotalUpVotes DESC, CloseReopenCount DESC;
