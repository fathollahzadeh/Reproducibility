
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(cht.Name, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes cht ON ph.PostHistoryTypeId = cht.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND
        cht.Id IN (1, 4, 10) 
    GROUP BY 
        ph.PostId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE 
            WHEN b.Class = 1 THEN 3
            WHEN b.Class = 2 THEN 2
            WHEN b.Class = 3 THEN 1 
            ELSE 0 END) AS TotalBadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.ViewCount,
        rp.Score,
        ph.HistoryCount,
        ph.ChangeTypes,
        ur.TotalBadgeScore,
        rp.UpvoteCount,
        rp.DownvoteCount,
        (COALESCE(rp.UpvoteCount, 0) - COALESCE(rp.DownvoteCount, 0)) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        UserReputation ur ON rp.OwnerName = ur.DisplayName
)

SELECT 
    PostId,
    Title,
    OwnerName,
    ViewCount,
    Score,
    COALESCE(HistoryCount, 0) AS HistoryCount,
    ChangeTypes,
    COALESCE(TotalBadgeScore, 0) AS TotalBadgeScore,
    UpvoteCount,
    DownvoteCount,
    NetVotes
FROM 
    FinalReport
ORDER BY 
    Score DESC, ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
