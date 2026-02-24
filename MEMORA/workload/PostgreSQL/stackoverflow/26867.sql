
WITH RecursiveTagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        RecursiveTagCounts
    WHERE 
        TagCount > 10 
),
MostVotedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
),
TopVotedQuestions AS (
    SELECT 
        QuestionId, 
        Title, 
        UpVotes, 
        DownVotes, 
        ROW_NUMBER() OVER (ORDER BY UpVotes DESC) AS VoteRank
    FROM 
        MostVotedQuestions
    WHERE 
        UpVotes > 5 
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
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
EnhanceQueries AS (
    SELECT 
        tt.TagName,
        tt.TagCount,
        tq.QuestionId,
        tq.Title,
        tq.UpVotes,
        tq.DownVotes,
        ub.BadgeCount, 
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        TopTags tt
    JOIN 
        TopVotedQuestions tq ON tq.Title LIKE '%' || tt.TagName || '%'
    JOIN 
        Users u ON u.Id = tq.QuestionId
    JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
)
SELECT 
    TagName,
    COUNT(DISTINCT QuestionId) AS RelatedQuestions,
    AVG(UpVotes) AS AvgUpVotes,
    AVG(DownVotes) AS AvgDownVotes,
    SUM(GoldBadges) AS TotalGoldBadges, 
    SUM(SilverBadges) AS TotalSilverBadges, 
    SUM(BronzeBadges) AS TotalBronzeBadges
FROM 
    EnhanceQueries
GROUP BY 
    TagName
ORDER BY 
    RelatedQuestions DESC, AvgUpVotes DESC;
