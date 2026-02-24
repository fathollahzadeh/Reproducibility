WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
AcceptedAnswers AS (
    SELECT 
        p.OwnerUserId,
        COUNT(a.Id) AS AcceptedAnswersCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(b.TotalBadges, 0) AS TotalBadges,
        COALESCE(ps.TotalVotes, 0) AS TotalVotes,
        COALESCE(ps.UpVotes, 0) AS UpVotes,
        COALESCE(ps.DownVotes, 0) AS DownVotes,
        COALESCE(aa.AcceptedAnswersCount, 0) AS AcceptedAnswersCount,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    LEFT JOIN 
        PostVoteStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        AcceptedAnswers aa ON u.Id = aa.OwnerUserId
),
FinalStats AS (
    SELECT 
        UserId,
        TotalBadges,
        TotalVotes,
        UpVotes,
        DownVotes,
        AcceptedAnswersCount,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC, TotalVotes DESC) AS Rank
    FROM 
        UserActivity
    WHERE 
        Reputation > 1000 
)

SELECT 
    u.DisplayName,
    fs.TotalBadges,
    fs.TotalVotes,
    fs.UpVotes,
    fs.DownVotes,
    fs.AcceptedAnswersCount,
    fs.Reputation,
    fs.Rank,
    CASE 
        WHEN fs.UpVotes > fs.DownVotes THEN 'Positive Contributor'
        WHEN fs.UpVotes < fs.DownVotes THEN 'Negative Contributor'
        ELSE 'Neutral Contributor'
    END AS ContributorType
FROM 
    FinalStats fs
JOIN 
    Users u ON fs.UserId = u.Id
WHERE 
    fs.Rank <= 10 
ORDER BY 
    fs.Rank;