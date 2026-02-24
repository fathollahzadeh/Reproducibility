
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Score, p.PostTypeId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        RANK() OVER (ORDER BY SUM(u.Reputation) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(u.Reputation) > 100
),
PostHistoryStats AS (
    SELECT
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        COALESCE(pv.HistoryCount, 0) AS HistoryCount,
        pv.LastEdited
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryStats pv ON rp.PostId = pv.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CommentCount,
    fp.HistoryCount,
    u.DisplayName,
    u.TotalUpVotes,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges
FROM 
    FilteredPosts fp
JOIN 
    TopUsers u ON fp.CommentCount > 5 AND fp.PostId IN (
        SELECT v.PostId 
        FROM Votes v 
        WHERE v.UserId = u.UserId AND v.VoteTypeId = 2
    )
ORDER BY 
    fp.Score DESC, u.TotalUpVotes DESC;
