WITH UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        u.DisplayName AS Author,
        b.BadgeCount,
        b.GoldBadges,
        b.SilverBadges,
        b.BronzeBadges
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteStats v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate BETWEEN '2021-01-01' AND '2023-10-01' 
        AND p.ViewCount > 100
),
MaxVotes AS (
    SELECT 
        PostId,
        ROW_NUMBER() OVER (PARTITION BY Author ORDER BY UpVotes DESC) AS VoteRank
    FROM 
        PostDetails
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.UpVotes,
    pd.DownVotes,
    pd.Author,
    pd.BadgeCount,
    pd.GoldBadges,
    pd.SilverBadges,
    pd.BronzeBadges,
    CASE 
        WHEN mv.VoteRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    PostDetails pd
LEFT JOIN 
    MaxVotes mv ON pd.PostId = mv.PostId
WHERE 
    pd.BadgeCount > 0
ORDER BY 
    pd.UpVotes DESC, pd.CreationDate DESC;
