
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id, 
        ph.PostId, 
        ph.UserId, 
        ph.CreationDate, 
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
),
PostHistories AS (
    SELECT
        php.PostId,
        MAX(CASE WHEN php.PostHistoryTypeId = 10 THEN php.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN php.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenTransitions,
        COUNT(CASE WHEN php.UserId IS NOT NULL THEN 1 END) AS EditCount,
        COUNT(DISTINCT CASE WHEN php.PostHistoryTypeId = 24 THEN php.UserId END) AS SuggestedEditsCount
    FROM 
        RecursivePostHistory php
    WHERE 
        php.rn = 1
    GROUP BY 
        php.PostId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ph.LastClosedDate,
        ph.CloseOpenTransitions,
        ph.EditCount,
        ph.SuggestedEditsCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistories ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 month'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        UpvotesReceived,
        DownvotesReceived,
        RANK() OVER (ORDER BY PostsCreated DESC) AS UserRank
    FROM 
        UserActivity
)

SELECT 
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreated,
    rp.Score AS PostScore,
    rp.ViewCount,
    COALESCE(ta.UserId, 0) AS TopUserId,
    COALESCE(ta.DisplayName, 'No top user') AS TopUserName,
    COALESCE(ta.PostsCreated, 0) AS TopUserPosts,
    COALESCE(ta.UpvotesReceived, 0) AS TopUserUpvotes,
    COALESCE(ta.DownvotesReceived, 0) AS TopUserDownvotes,
    rp.LastClosedDate,
    rp.CloseOpenTransitions,
    rp.EditCount,
    rp.SuggestedEditsCount
FROM 
    RecentPosts rp
LEFT JOIN 
    TopUsers ta ON rp.Score = (SELECT MAX(Score) FROM RecentPosts WHERE Score IS NOT NULL)
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;
