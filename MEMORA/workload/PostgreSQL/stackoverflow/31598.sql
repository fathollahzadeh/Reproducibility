WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 AND SUM(p.Score) IS NOT NULL
),
NextPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(nph.PostId) AS RevCount,
        MAX(nph.CreationDate) AS LastRevision,
        COUNT(DISTINCT ph.UserId) AS UserCount,
        (SELECT COUNT(1) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS TotalDownVotes 
    FROM 
        Posts p
    JOIN 
        NextPostHistory nph ON p.Id = nph.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.ClosedDate IS NOT NULL 
    GROUP BY 
        p.Id
),
FinalReport AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.TotalScore,
        tu.TotalPosts,
        cp.PostId,
        cp.RevCount,
        cp.UserCount,
        cp.LastRevision,
        cp.TotalDownVotes
    FROM 
        TopUsers tu
    JOIN 
        ClosedPosts cp ON tu.UserId = cp.PostId
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.TotalScore,
    fr.TotalPosts,
    fr.PostId,
    fr.RevCount,
    fr.UserCount,
    fr.LastRevision,
    fr.TotalDownVotes
FROM 
    FinalReport fr
ORDER BY 
    fr.TotalScore DESC, fr.UserCount DESC;