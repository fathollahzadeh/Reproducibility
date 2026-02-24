
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        u.Reputation, 
        COUNT(p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(p.Id) > 0
), RecentVotes AS (
    SELECT 
        v.UserId, 
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        v.UserId
), ConsolidatedUserActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.QuestionCount,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        COALESCE(rv.UpVotes, 0) AS UpVoteCount,
        COALESCE(rv.DownVotes, 0) AS DownVoteCount
    FROM 
        UserActivity ua
    LEFT JOIN 
        RecentVotes rv ON ua.UserId = rv.UserId
), TagInfo AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.ViewCount) AS AverageViewCount,
        SUM(COALESCE(p.FavoriteCount, 0)) AS TotalFavorites
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
), TopTags AS (
    SELECT 
        TagName, 
        PostCount, 
        AverageViewCount,
        TotalFavorites,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagInfo
)
SELECT 
    cua.UserId,
    cua.DisplayName,
    cua.Reputation,
    cua.QuestionCount,
    cua.RecentVoteCount,
    cua.UpVoteCount,
    cua.DownVoteCount,
    tt.TagName,
    tt.PostCount,
    tt.AverageViewCount,
    tt.TotalFavorites
FROM 
    ConsolidatedUserActivity cua
LEFT JOIN 
    TopTags tt ON tt.Rank <= 5
ORDER BY 
    cua.Reputation DESC, 
    tt.PostCount DESC
LIMIT 100;
