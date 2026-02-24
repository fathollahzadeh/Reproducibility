WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(CASE WHEN b.Class IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), UserVotingHistory AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN vt.Name = 'Close' THEN 1 ELSE 0 END) AS CloseVotes,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
), PopularPostTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS Tag,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL AND 
        p.ViewCount > 100
    GROUP BY 
        Tag
    ORDER BY 
        PostCount DESC
    LIMIT 10
), DetailedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeletionCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 14 THEN 1 END) AS LockCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
), CombinedData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ub.TotalBadges,
        uv.TotalVotes AS UserTotalVotes,
        uv.UpVotes,
        uv.DownVotes,
        (COALESCE(dph.CloseCount, 0) + COALESCE(dph.DeletionCount, 0) + COALESCE(dph.LockCount, 0)) AS TotalPostIssues,
        COALESCE(pt.PostCount, 0) AS PopularPostTagsCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        UserVotingHistory uv ON u.Id = uv.UserId
    LEFT JOIN 
        DetailedPostHistory dph ON u.Id = dph.PostId
    LEFT JOIN 
        (SELECT 
            p.OwnerUserId,
            COUNT(DISTINCT pt.Tag) AS PostCount
        FROM 
            Posts p
        JOIN 
            PopularPostTags pt ON pt.Tag = ANY(string_to_array(p.Tags, ','))
        GROUP BY 
            p.OwnerUserId) pt ON u.Id = pt.OwnerUserId
)
SELECT 
    cd.UserId,
    cd.DisplayName,
    cd.GoldBadges,
    cd.SilverBadges,
    cd.BronzeBadges,
    cd.TotalBadges,
    cd.UserTotalVotes,
    cd.UpVotes,
    cd.DownVotes,
    cd.TotalPostIssues,
    cd.PopularPostTagsCount,
    CASE 
        WHEN cd.TotalBadges > 5 THEN 'Active Contributor' 
        ELSE 'New User' 
    END AS UserCategory
FROM 
    CombinedData cd
WHERE 
    cd.UserId IN (
        SELECT DISTINCT OwnerUserId 
        FROM Posts 
        WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    )
ORDER BY 
    cd.PopularPostTagsCount DESC,
    cd.UserTotalVotes DESC
LIMIT 50;