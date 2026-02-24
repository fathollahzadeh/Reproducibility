WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS NumQuestions
    FROM 
        PostTags
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        NumQuestions,
        ROW_NUMBER() OVER (ORDER BY NumQuestions DESC) AS Rank
    FROM 
        TagCounts
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.PostId) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(uv.VoteCount, 0) AS TotalVotes,
    COALESCE(uv.UpVoteCount, 0) AS TotalUpVotes,
    COALESCE(uv.DownVoteCount, 0) AS TotalDownVotes,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS TotalGoldBadges,
    COALESCE(ub.SilverBadges, 0) AS TotalSilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS TotalBronzeBadges,
    tt.TagName,
    tt.NumQuestions AS QuestionsTagged
FROM 
    Users u
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    TopTags tt ON tt.Rank <= 10
ORDER BY 
    tt.NumQuestions DESC, u.Reputation DESC
LIMIT 50;