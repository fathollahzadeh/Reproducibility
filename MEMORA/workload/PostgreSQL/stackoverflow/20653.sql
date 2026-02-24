
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users u
        LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        us.TotalBounties,
        us.TotalUpVotes,
        us.TotalDownVotes,
        pa.EditCount,
        pa.LastEditDate,
        pa.CloseCount
    FROM 
        RankedPosts rp
        JOIN UserStats us ON us.UserId = rp.OwnerUserId
        JOIN PostActivity pa ON pa.PostId = rp.PostId
    WHERE 
        rp.ScoreRank = 1 
        AND (us.TotalBounties > 0 OR us.TotalUpVotes > us.TotalDownVotes) 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.AnswerCount,
    fp.TotalBounties,
    fp.TotalUpVotes,
    fp.TotalDownVotes,
    CASE 
        WHEN fp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open' 
    END AS Status,
    CONCAT(CAST(fp.LastEditDate AS TEXT), ' ', COALESCE(fp.EditCount, 0)::TEXT, ' edits') AS EditInfo
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC
LIMIT 100;
