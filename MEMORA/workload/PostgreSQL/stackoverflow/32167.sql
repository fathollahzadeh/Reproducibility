
WITH RecursivePost AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        p.OwnerUserId
    FROM 
        Posts AS p
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT bh.Id) AS BadgeCount,
        SUM(COALESCE(ph.Score, 0)) AS TotalPostScore,
        SUM(COALESCE(ph.ViewCount, 0)) AS TotalViews
    FROM 
        Users AS u
    LEFT JOIN 
        Badges AS bh ON u.Id = bh.UserId
    LEFT JOIN 
        Posts AS ph ON u.Id = ph.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ua.DisplayName AS OwnerDisplayName,
        ua.Reputation,
        ua.BadgeCount,
        rp.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY rp.TotalBounty DESC, rp.Score DESC) AS PostRank
    FROM 
        RecursivePost AS rp
    JOIN 
        UserActivity AS ua ON rp.OwnerUserId = ua.UserId
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.Reputation,
    pd.BadgeCount,
    pd.TotalBounty,
    pd.PostRank
FROM 
    PostDetails AS pd
WHERE 
    pd.PostRank <= 10 
ORDER BY 
    pd.TotalBounty DESC, pd.Score DESC;
