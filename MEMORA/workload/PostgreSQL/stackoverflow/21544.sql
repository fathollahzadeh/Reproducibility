
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        p.CreationDate,
        COALESCE(p.ClosedDate, '9999-12-31') AS EffectiveCloseDate,
        p.OwnerUserId
    FROM 
        Posts p
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 1) THEN 1 ELSE 0 END) AS PositiveVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id,
        ph.PostHistoryTypeId,
        ph.CreationDate AS ClosedDate,
        cr.Name AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS varchar)
    WHERE 
        ph.PostHistoryTypeId = 10
),
TopUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        TotalComments,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    u.DisplayName AS Author,
    u.Reputation,
    tp.TotalPosts,
    tp.UpVotes,
    tp.DownVotes,
    cp.ClosedDate,
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers tp ON tp.UserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.Id
WHERE 
    rp.Rank <= 5
    AND (rp.EffectiveCloseDate = '9999-12-31' OR cp.ClosedDate IS NOT NULL)
    AND (u.Reputation > 50 OR u.Location IS NOT NULL)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 10;
